"""
Email Service - Alert notifications
"""

import logging
from typing import Optional, List
from datetime import datetime
import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from core.config import settings

logger = logging.getLogger(__name__)


class EmailService:
    """Email notification service"""
    
    def __init__(self):
        self.smtp_host = settings.SMTP_HOST
        self.smtp_port = settings.SMTP_PORT
        self.smtp_user = settings.SMTP_USER
        self.smtp_password = settings.SMTP_PASSWORD
        self.from_email = settings.EMAIL_FROM
        
    async def send_email(
        self,
        to_email: str,
        subject: str,
        body: str,
        html: Optional[str] = None
    ) -> bool:
        """
        Send email notification
        """
        if not self.smtp_user or not self.smtp_password:
            logger.warning("Email not configured - skipping send")
            return False
            
        try:
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = self.from_email
            message["To"] = to_email
            
            # Plain text part
            text_part = MIMEText(body, "plain")
            message.attach(text_part)
            
            # HTML part (if provided)
            if html:
                html_part = MIMEText(html, "html")
                message.attach(html_part)
            
            await aiosmtplib.send(
                message,
                hostname=self.smtp_host,
                port=self.smtp_port,
                username=self.smtp_user,
                password=self.smtp_password,
                start_tls=True
            )
            
            logger.info(f"Email sent to {to_email}: {subject}")
            return True
            
        except Exception as e:
            logger.error(f"Error sending email: {e}")
            return False
    
    async def send_alert(
        self,
        to_email: str,
        alert_type: str,
        child_name: str,
        details: str
    ) -> bool:
        """
        Send alert notification
        """
        subject_map = {
            "leave_too_long": f"⚠️ {child_name} 离开时间过长",
            "play_while_work": f"📱 {child_name} 边玩边学",
            "session_start": f"✅ {child_name} 开始学习了",
            "session_end": f"🏁 {child_name} 学习结束"
        }
        
        body_map = {
            "leave_too_long": f"提醒：{child_name} 已经离开超过15分钟了。请关注。",
            "play_while_work": f"提醒：检测到{child_name}一边学习一边玩耍超过5分钟。",
            "session_start": f"{child_name}已开始学习。学习时长统计已开始。",
            "session_end": f"{child_name}今日学习已结束。详情请查看学习报告。"
        }
        
        subject = subject_map.get(alert_type, f"HomeworkGuardian 提醒")
        body = body_map.get(alert_type, details)
        
        html = f"""
        <html>
        <body>
            <h2>{subject}</h2>
            <p>{body}</p>
            <p>时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
            <hr>
            <p><small>来自 HomeworkGuardian 家庭作业监控系统</small></p>
        </body>
        </html>
        """
        
        return await self.send_email(to_email, subject, body, html)
    
    async def send_daily_report(
        self,
        to_email: str,
        child_name: str,
        report_data: dict
    ) -> bool:
        """
        Send daily learning report
        """
        subject = f"📊 {child_name} 今日学习报告"
        
        study_hours = report_data.get("total_study_time", 0) / 3600
        focus_score = report_data.get("focus_score", 0)
        
        body = f"""
        {child_name} 今日学习报告
        
        学习时长: {study_hours:.1f} 小时
        专注度: {focus_score:.1f}%
        
        详细活动统计:
        - 学习: {report_data.get('activities', {}).get('studying', 0) // 60} 分钟
        - 发呆: {report_data.get('activities', {}).get('idle', 0) // 60} 分钟
        - 离开: {report_data.get('activities', {}).get('away', 0) // 60} 分钟
        - 玩耍: {report_data.get('activities', {}).get('playing', 0) // 60} 分钟
        
        发送时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        """
        
        html = f"""
        <html>
        <body>
            <h2>📊 {child_name} 今日学习报告</h2>
            <table>
                <tr><td><b>学习时长</b></td><td>{study_hours:.1f} 小时</td></tr>
                <tr><td><b>专注度</b></td><td>{focus_score:.1f}%</td></tr>
            </table>
            <hr>
            <p><small>来自 HomeworkGuardian</small></p>
        </body>
        </html>
        """
        
        return await self.send_email(to_email, subject, body, html)
    
    async def send_test_email(self, to_email: str) -> bool:
        """
        Send test email
        """
        return await self.send_email(
            to_email,
            "✅ HomeworkGuardian 测试邮件",
            "这是一封测试邮件，确认邮件推送功能正常。"
        )
